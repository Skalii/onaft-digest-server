package volkova.restful.digest.entity

import com.fasterxml.jackson.annotation.JsonIgnoreProperties
import com.fasterxml.jackson.annotation.JsonProperty
import com.fasterxml.jackson.annotation.JsonPropertyOrder
import javax.persistence.*
import javax.validation.constraints.NotNull

@Entity(name = "Keyword")
@JsonPropertyOrder(value = ["id_keyword", "word"])  // последователность
@SequenceGenerator(
        name = "keywords_seq",
        sequenceName = "keywords_id_keyword_seq",
        schema = "public",
        allocationSize = 1
)
@Table(
        name = "keywords",
        schema = "public",
        indexes = [
            Index(name = "keywords_pkey",
                    columnList = "id_keyword",
                    unique = true),
            Index(name = "keywords_id_keyword_uindex",
                    columnList = "id_keyword",
                    unique = true),
            Index(name = "keywords_word_uindex",
                    columnList = "word",
                    unique = true)])
class Keyword (
    @Column(name = "id_keyword",
            nullable = false)
    @GeneratedValue(
            strategy = GenerationType.SEQUENCE,
            generator = "keywords_seq")
    @Id
    @get:JsonProperty(value = "id_keyword") // как именуюется
    @NotNull
    val idKeyword: Int = 0,

    @Column(name = "word",
            nullable = false)
    @get:JsonProperty(value = "word")
    @NotNull
    val word: String = ""
){

    @JoinTable(
            name = "publications_keywords",
            joinColumns = [JoinColumn(
                    name = "id_keyword",
                    nullable = false,
                    foreignKey = ForeignKey(name = "publications_keywords_id_keyword_fk"))],
            inverseJoinColumns = [JoinColumn(
                    name = "id_publication",
                    nullable = false,
                    foreignKey = ForeignKey(name = "publications_keywords_id_publication_fk"))])
    @JsonIgnoreProperties(value = ["keyword"])
    @get:JsonProperty(value = "publications")
    @ManyToMany(cascade = [CascadeType.ALL])
    lateinit var publications: MutableList<Publication>

    constructor() : this(
            0,
            ""
    )


}