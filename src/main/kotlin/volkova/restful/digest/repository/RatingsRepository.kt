package volkova.restful.digest.repository


import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.data.repository.Repository as EmptyRepository
import org.springframework.stereotype.Repository

import volkova.restful.digest.entity.Rating


@Repository
interface RatingsRepository : EmptyRepository<Rating, Int> {

    @Query(value = """select (rating_record(cast_int(:id_rating))).*""",
            nativeQuery = true)
    fun find(@Param("id_rating") idRating: Int? = null): Rating

    @Query(value = """select (keyword_record(all_record => true)).*""",
            nativeQuery = true)
    fun findAll(): MutableList<Rating>

    @Query(value = """select (rating_insert(
                          cast_dp(:#{#rating.stars}),
                          cast_int(:#{#rating.seen})
                      )).*""",
            nativeQuery = true)
    fun add(@Param("rating") newRating: Rating): Rating

    @Query(value = """select (rating_update(
                          cast_dp(:#{#rating.stars}),
                          cast_int(:#{#rating.seen}),
                          cast_int(:#{#rating.idKeyword})
                      )).*""",
            nativeQuery = true)
    fun set(@Param("rating") newRating: Rating): Rating

    @Query(value = """select (rating_delete(cast_int(:id_rating))).*""",
            nativeQuery = true)
    fun remove(@Param("id_rating") idRating: Int): Rating

}